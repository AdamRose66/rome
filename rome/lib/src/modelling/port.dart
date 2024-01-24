/*
Copyright 2024 Adam Rose

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'dart:mirrors';

import 'module.dart';

///
/// Ports and Connectivity
///

//
// The user visible class in here is Port<IF>.
//
// This provides a module aware proxy for an interface of type IF. Ports can be
// connection locally within a module, but the end effect is that a call to an
// interface method in a port in one part of the module hierarchy is executed
// *directly* in a module in another part of the hierarchy, as specified by the
// chain of port connections.
//
// A mechanism like this was first implemented in SystemC and then copied over
// into SystemVerilog ( eg tlm and analysis ports ).
//
// This is the "third ingredient" needed to do Modeling. The first two (
// module hierarchy and simulator time ) already exist in Rohd.
//
// This code is a prototype. The idea is that it is integrated into the
// current Rohd implementations of Module, Simulator, etc.
//

//
// TBD : add some ( possibly optional ) subtypes / mixins which provide
// hierarchy / role checking check child.p -> p -> e -> child.e
// ( ie something like sc_port/sc_export )
//
// TBD : add bidirectional initiator<REQ_IF,RSP_IF> and target<REQ_IF,RSP_IF>
// where REQ_IF is initiator -> target and RSP_IF is target -> Initiator.
// This would be the underlying mechanism for a Rohd/Dart TLM 2.0 equivalent.
//
// TBD : port arrays
//

//
// A non-generic abstract PortBase class
//
abstract class PortBase extends NamedComponent
{
  PortBase( super.name , [super.parent] );

  void doConnections();

  // isStartPort true then this is an inappropriate place to call doConnections
  bool get isStartPort => _isStartPort;

  bool debugConnections = true;
  bool _isStartPort = true;
}

//
// The concrete generic Port class
//
class Port<IF extends Object> extends PortBase
{
  Port( super.name , [super.parent] );

  Port<IF>? connectedTo;

  //
  // connects to other ports of type Port<TO_IF extends IF> ( because of generic invariance )
  //
  // compile error if IF types are not compatible
  //
  operator<=( Port<IF> p )
  {
    connectedTo = p;

    //
    // mark the port we are connecting to as an inappropriate place
    // from which to call doConnections
    //
    p._isStartPort = false;

    if( debugConnections )
    {
      print('Connections Debug: Connecting $fullName type $runtimeType to $p.fullName type $p.runtimeType');
    }
  }

  IF call()
  {
    return portIf;
  }

  //
  // delegates method call to portIf
  //
  // Note : this only works if the Port class implements the IF
  //
  // If that is the case, then we can do eg p.read( addr , data ) where
  // read is a method in IF
  //
  @override
  dynamic noSuchMethod( Invocation invocation )
  {
    return reflect( portIf ).delegate( invocation );
  }

  //
  // Used externally to connect a (Ex)Port to an interface
  //
  // Used internally by _doConnections(.)
  //
  void implementedBy( IF to , [bool? debug] )
  {
    debug ??= debugConnections;

    _if = to;

    if( debug )
    {
      String toName = 'unknown';

      if( to is NamedComponent )
      {
        toName = to.fullName;
      }

      print('Connections Debug: Port $fullName type $runtimeType is implemented by $toName type $to.runtimeType');
    }
  }

  @override
  void doConnections()
  {
    if( connectedTo != null )
    {
      _doConnections( connectedTo! , debugConnections );
    }
  }

  void _doConnections( Port<IF> to , bool debug )
  {
    if( _if != null )
    {
      // we've been here before, so don't recurse again
      return;
    }

    if( to.connectedTo != null )
    {
      to._doConnections( to.connectedTo! , debug );
    }

    // assign from the 'to' end of the connection chain backwards along the chain
    // the net effect is that an interface moves backwards along the chain of
    // connection from the furthest "connectedTo" to the nearest "connectedFrom"

    implementedBy( connectedTo!.portIf , debug );
  }

  //
  // the actual underlying interface, ultimately sourced from the end of the connectedTo chain
  //
  IF get portIf
  {
    if( _if == null )
    {
      throw ProbableConnectionError( this );
    }
    return _if!;
  }

  IF? _if;
}

class ProbableConnectionError extends Error
{
  PortBase p;

  ProbableConnectionError( this.p );

  @override
  String toString()
  {
    return 'Port Connection Error: null interface on $p.fullName type $runtimeType. This indicates some kind of connection error.';
  }
}
