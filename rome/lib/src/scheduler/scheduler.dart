/*
Copyright 2024 Adam Rose

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'dart:collection';
import 'dart:async';

//
// A process is just a Completer<void> for the Future<void> returned by
// Scheduler.delay( time  s)
//
typedef Process = Completer<void>;
typedef ProcessQueue = ListQueue<Process>;

//
// The Scheduler class contains:
// - a TimeSlot for the next delta
// - a TimeSlot for all future times that have been scheduled
//
// A process is added to the scheduler by calling yield scheduler.delay(.).
//
// This adds a Completer<void> to the relevant timeSlot ( creating a new
// TimeSlot if needed ).
//
// ExecuteUntil calls executeProcesses on the youngest TimeSlot, and will loop
// through the TimeSlots in order until either we time out or there are no more
// TimeSlots to process.
//
// During this iteration, any given TimeSlot may create new TimeSlots as a
// result of one its processes calling yield scheduler.delay(.)
//
// Each new timeSlot is separated from the next by a Duration.zero in
// Dart event wheel.
//
class Scheduler
{
  Future<Time> executeUntil( [int timeLimit = Time.maxTime] ) async
  {
    assert( currentTime.time < Time.maxTime );

    for( TimeSlot? timeSlot = popNextTimeSlot( timeLimit );
         timeSlot != null;
         timeSlot = popNextTimeSlot( timeLimit ) )
    {
      currentTime = timeSlot.time;

      timeSlot.executeProcesses();
      await Future.delayed( Duration.zero );
    }

    return currentTime;
  }

  //
  // This Future<void> creates a Completer and adds it to the TimeSlot for
  // later completion. It returns the Completer to the caller so that the
  // caller can await it.
  //
  Future<void> delay( int timeIncrement )
  {
    Process p = Completer();

    TimeSlot timeSlot = getTimeSlot( timeIncrement );

    timeSlot.addProcess( p );

    return p.future;
  }

  //
  // returns the next TimeSlot and pops it from whatever container it's in.
  //
  // returns null if there are no more timeSlots, or if the next time slot
  // is scheduled for after the time limit
  //
  TimeSlot? popNextTimeSlot( int timeLimit )
  {
    TimeSlot? timeSlot;

    if( nextDelta != null )
    {
        timeSlot = nextDelta;
        assert( timeSlot!.time.time <= timeLimit );
        nextDelta = null;
    }

    else if( _eventQueues.isNotEmpty )
    {
      int key = _eventQueues.firstKey()!;
      timeSlot = _eventQueues[key];

      if( key > timeLimit ) {
        return null;
      }

      _eventQueues.remove( key );
    }

    return timeSlot;
  }

  //
  // lazily gets the time slot at currentTime + timeIncrement
  // ( if timeIncrement is zero then the Slot is nextDelta )
  //
  TimeSlot getTimeSlot( int timeIncrement )
  {
    if( timeIncrement == 0 )
    {
      nextDelta = nextDelta ?? TimeSlot( Time( currentTime.time , currentTime.delta + 1  ) , this );
      return nextDelta!;
    }
    else
    {
      int newTime = currentTime.time + timeIncrement;
      _eventQueues[newTime] = _eventQueues[newTime] ?? TimeSlot( Time( newTime , 0 ) , this );
      return _eventQueues[newTime]!;
    }
  }

  // saves a small amount of typing ...
  String get timeStamp
  {
    return('timeStamp $currentTime');
  }

  //
  // simulation starts with currentTime = Time( 0 , -1 ), so anything added
  // before sim starts will result in a timeSlot at Time( 0 , 0 ) ) or later.
  //
  Time currentTime = Time( 0 , -1 );

  // the (possibly null) list of processes in the next delta
  TimeSlot? nextDelta;

  // a map of timeslots, ordered by time
  final SplayTreeMap<int,TimeSlot> _eventQueues = SplayTreeMap();
}

//
// A timeSlot is created by the Scheduler for a particular time,delta pair
//
// Previous ( or even the current ) timeSlots may add processes to the process
// queue by calling yield scheduler.delay( time ). A process is actually the
// Completer<void> returned created by scheduler.delay( time ).
//
// The scheduler calls TimeSlot.executeProcesses(). All that does is call
// complete on all the processes ( ie Completers ) in the TimeSlot. Calling
// complete unblocks await scheduler.delay(.) in the previously blocked process,
// allowing the async function to resume execution at the specified Time.
//
class TimeSlot
{
  // the (time,delta) for this time slot
  final Time time;

  //
  // A pointer back to the scheduler. Actually, this is only needed for debug
  // purposes, so maybe remove it ?
  //
  final Scheduler scheduler;

  //
  // The list of processes in this timeSlot
  //
  ProcessQueue processes = ListQueue();

  TimeSlot( this.time , this.scheduler );

  //
  // Called by the scheduler to add a process ( aka Completer ) to this TimeSlot
  //
  void addProcess( Process p )
  {
    processes.add( p );
  }

  //
  // Complete the processes in this timeSlot, popping from the list as we go.
  //
  // Not using an iterator means that we are safe to add things to this list
  // while the list is being processed
  //
  void executeProcesses()
  {
    print('$scheduler.timeStamp');

    assert( processes.isNotEmpty );

    while( processes.isNotEmpty )
    {
      Process p = processes.removeFirst();
      p.complete();
    }
  }

  // save a tiny amount of typing
  String get timeStamp
  {
    return 'TimeSlot $time';
  }
}

//
// Time is modelled as a time,delta pair
//
class Time
{
  // quite why eg 1<<63 doesn't work, I don't know ...
  static const int maxTime = (1 << 62);

  int time = 0 , delta = 0;

  Time( this.time , this.delta );
  Time.copy( Time other ) : this( other.time , other.delta );

  @override
  String toString()
  {
    return 'time $time delta $delta';
  }

  // could use https://pub.dev/packages/equatable if we cared enough ...

  @override
  bool operator==( covariant Time other )
  {
    return time == other.time && delta == other.delta;
  }

  @override
  int get hashCode => (time,delta).hashCode;
}
