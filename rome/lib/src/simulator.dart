/*
Copyright 2024 Adam Rose

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'modelling/module.dart';
import 'scheduler/scheduler.dart';

//
// A Simulator is the combination of a Scheduler and a module-aware phasing
// engine.
//
// It has a scheduler singleton and uses the visit(.) function to recurse
// through the Module hierarchy.
//
// There are four phases. The first three are all synchronous. Only the last
// phase, the run phase, is asynchronous.
//
// (1) Construction Phase
// This phase is an implicit phase, started by calling the constructor of the
// top level object. The components construct themselves by constructing
// children inside their own constructors. This is also the place where (ex)port
// to implementation binding should be specified, using the
// Port.implementedBy function.
//
// (2) Connect Phase
// Module authors use the Connect Phase to specify port to (ex)port binding,
// using the <= operator. This is more of a convenience than a necessity - the
// connections could also be done in the constructor, after the children have
// been constructed.
//
// (3) postConnect ( private )
// The postConnect phase is a private phase, only intended for use by the
// Port infrastructure. This is where the port->port->export->implementation
// chains are resolved, with the implementation being copied backwards along
// the chain by Port._doConnections.
//
// (4) Run Phase
// This is where the actual behaviour of the Modules is defined. The Module.run
// method is async, although it does not return a future. It is expected that
// await is used in here to wait for time ( eg await scheduler.delay( time ); )
// or for any other Futures that make sense in this model.
//

// the Scheduler singleton
Scheduler scheduler = Scheduler();

// a convenience, to hider the scheduler
Future<void> delay( int timeIncrement ) async
{
  await scheduler.delay( timeIncrement );
}

// the phasing implementation
void simulate( Module top , [int delay = Time.maxTime]) async
{
  // a bit of hierarchy debug
  visit( top , topDown : ( Module m ) {
    print('instance ${m.fullName} type ${m.runtimeType}');

    for( NamedComponent c in m.children )
    {
      if( c is! Module )
      {
        print('instance ${c.fullName} type ${c.runtimeType}');
      }

    }
  } );

  // the three explicit phases
  visit( top , bottomUp : ( Module m ) { m.connect(); } );
  visit( top , bottomUp : ( Module m ) { m.postConnect(); } );
  visit( top , bottomUp : ( Module m ) { m.run(); } );

  // wait until the simulation is done
  await scheduler.executeUntil( delay );
  top.mPrint('gracefully ending simulation');
}
