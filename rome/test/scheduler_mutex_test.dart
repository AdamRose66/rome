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

Future<void> mutexTest( int? delay , int loops ) async
{
  print('starting mutexTest $delay');
  Scheduler scheduler = Scheduler();

  List<Time> criticalA = [];
  List<Time> criticalB = [];

  Mutex mutex = Mutex( scheduler , 'mutex' , delay: delay );

  greedy( scheduler , 'a' , loops , mutex , criticalA );
  greedy( scheduler , 'b' , loops , mutex , criticalB );

  await scheduler.executeUntil( 1000 );

  expect( criticalA.length , equals( loops ) );
  expect( criticalB.length , equals( loops ) );

  expectNoOverlap( criticalA , criticalB );

  print('done mutex test\n\n');
}

Future<void> greedy( Scheduler scheduler , String name , int loops , Mutex m , List<Time> criticalSections ) async
{
  for( int i = 0; i < loops; i++ )
  {
    await scheduler.delay( 10 );

    await m.lock();
    criticalSections.add( Time.copy( scheduler.currentTime ) );

    print('  $name: starting critical section $i');
    await scheduler.delay( 10 );
    print('  $name: ending critical section $i');

    await m.unlock();
  }
}

void expectNoOverlap( List<Time> l1 , List<Time> l2 )
{
  for( Time t1 in l1 )
  {
    for( Time t2 in l2 )
    {
      expect( t1 , isNot( equals( t2 ) ) );
    }
  }
}

//
// this is by no means an exhaustive test of Mutex, and we haven't even
// started on Semaphore with size > 1
//
// But the basic functioning of a mutex with time critical sections is tested
// below
//
void main() async {
  group('A group of tests', () {
    setUp(() {
    });

    test('Mutex Test', () async {
      await mutexTest( 0 , 3 );
      await mutexTest( 10 , 3 );
      await mutexTest( null , 3 );
    });
  });
}
