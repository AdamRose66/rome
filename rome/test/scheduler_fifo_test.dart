/*
Copyright 2024 Adam Rose

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'dart:async';

import 'package:rome/rome.dart';
import 'package:test/test.dart';


Future<void> fifoTest( int? delay , int size ) async
{
  print('starting fifoTest $delay');
  Scheduler scheduler = Scheduler();
  int expectedDeltas;

  final int n = 4;
  final int effectiveTransactions = size == 1 ? n * 2 : n + 1;

  if( delay == null )
  {
    expectedDeltas = -1;
  }
  else if( delay == 0 )
  {
    expectedDeltas = effectiveTransactions - 1;
  }
  else
  {
    expectedDeltas = 0;
  }

  Time expectedTime = Time( (delay ?? 0) * effectiveTransactions ,
                            expectedDeltas );

  Fifo<int> fifo = Fifo( scheduler , 'fifo' , delay : delay , size : size );

  producer( scheduler , 'producer' , n  , fifo );
  consumer( scheduler , 'consumer' , n , fifo );

  await scheduler.executeUntil( 100 );
  print('finished fifoTest $delay\n\n');

  expect( scheduler.currentTime , equals( expectedTime ) );
}

Future<void> producer( Scheduler scheduler , String name , int n , Fifo<int> fifo ) async
{
  for( int i = 0; i < n; i++ )
  {
    print('  $name just about to put $i at ${scheduler.timeStamp}');
    await fifo.put( i );
    print('  $name just done put $i at ${scheduler.timeStamp}');

  }
}

Future<void> consumer( Scheduler scheduler , String name , int n , Fifo<int> fifo ) async
{
  for( int i = 0; i < n; i++ )
  {
    print('  $name just about to get at $scheduler.timeStamp');
    int v = await fifo.get();
    print('  $name just done get $v at $scheduler.timeStamp');

    expect( i , equals( v ) );
  }
}

void main() async {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Fifo Test', () async {
      await fifoTest( null , 1 );
      await fifoTest( 0 , 1 );
      await fifoTest( 10 , 1 );

      await fifoTest( null , 2 );
      await fifoTest( 0 , 2 );
      await fifoTest( 10 , 2 );
    });
  });
}
