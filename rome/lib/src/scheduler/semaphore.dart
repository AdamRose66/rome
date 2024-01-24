/*
Copyright 2024 Adam Rose

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'dart:async';

import 'scheduler.dart';

abstract interface class SemaphoreIf
{
  Future<void> release( [int n = 1] );
  Future<void> acquire( [int n = 1] );
}

abstract interface class MutexIf
{
  Future<void> lock();
  Future<void> unlock();
}

//
// This is a scheduler aware Semaphore.
//
// It starts with size resources. await acquire( n ) waits until it is possible
// to acquire n of those resources. await release( n ) waits until it is
// possible to release n resources without exceeding size.
//
// Discussion :
// (1) should acquire be a Future<int>, and allow a return with less
// than the number of resources requested ? Should it have a second method
// with that behaviour eg Future<int> acquireUpTo( int n ) ?
// (2) We should throw if n < 1.
//
class Semaphore implements SemaphoreIf
{
  int _remaining;

  final Scheduler scheduler;
  final String name;
  final int size;

  final int? delay;

  Semaphore( this.scheduler , this.name , {this.delay = 0 , this.size = 1} ) : _remaining = size;

  int get used => size - _remaining;
  int get available => _remaining;

  Completer<void> _justReleased = Completer();
  Completer<void> _justAcquired = Completer();

  @override
  Future<void> release( [int n = 1] ) async
  {
    while( used > n )
    {
      await _justAcquired.future;
      _justAcquired = Completer();
    }

    if( delay != null )
    {
        await scheduler.delay( delay! );
    }

    // provide keys after optional delay
    _remaining += n;
    if( !_justReleased.isCompleted ) _justReleased.complete();
  }

  @override
  Future<void> acquire( [int n = 1] ) async
  {
    while( available < n )
    {
      await _justReleased.future;
      _justReleased = Completer();
    }

    // immediately reduce available keys
    _remaining -= n;

    if( delay != null )
    {
        await scheduler.delay( delay! );
    }

    if( !_justAcquired.isCompleted ) _justAcquired.complete();
  }

}

//
// A Mutex is a Semaphore of size one with different names for the methods.
//
class Mutex extends Semaphore implements MutexIf
{
  Mutex( Scheduler scheduler , String name , {int? delay = 0} ) : super( scheduler , name , delay: delay , size: 1 );

  @override
  Future<void> lock() async
  {
    await acquire();
  }

  @override
  Future<void> unlock() async
  {
    await release();
  }
}
