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

import 'scheduler.dart';

abstract interface class FifoPutIf<T>
{
    Future<void> put( T t );
    bool canPut();
}

abstract interface class FifoGetIf<T>
{
    Future<T> get();
    bool canGet();
}

class Fifo<T> implements FifoPutIf<T> , FifoGetIf<T>
{
  final ListQueue<T> _data = ListQueue();

  final int? delay;
  final int size;
  final Scheduler scheduler;
  final String name;

  Fifo( this.scheduler , this.name , {this.delay = 0 , this.size = 1} )
  {
    if( size < 1 )
    {
      throw FifoSizeError( size );
    }
  }

  Completer<void> _justSet = Completer();
  Completer<void> _justConsumed = Completer();

  @override
  Future<void> put( T t ) async
  {
    if( !canPut() )
    {
      await _justConsumed.future;
    }

    if( delay != null )
    {
      await scheduler.delay( delay! );
    }

    _data.addFirst( t );

    if( !_justSet.isCompleted ) _justSet.complete();
    _justConsumed = Completer();
  }

  @override
  Future<T> get() async
  {
    if( !canGet() )
    {
      await _justSet.future;
    }

    // immediately block other gets
    T newT = _data.last;

    if( delay != null )
    {
        await scheduler.delay( delay! );
    }

    _data.removeLast();
    if( !_justConsumed.isCompleted ) _justConsumed.complete();
    _justSet = Completer();

    return newT;
  }

  @override
  bool canGet() => _data.isNotEmpty;

  @override
  bool canPut() => _data.length < size;
}

class FifoSizeError extends Error
{
  int size;
  FifoSizeError( this.size );

  @override
  String toString()
  {
    return 'size must be greater or equal to one, but $size was observed';
  }
}
