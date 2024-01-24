/*
Copyright 2024 Adam Rose

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import '../modelling.dart';
import 'memory.dart';

//
// This simple Router receives inbound calls to read and write and forwards
// them to the correct initiator port, according to the memory map stored in
// _initiatorPorts.
//
// These ports are specified by a list of (start_address,end_address,name)
// triplets which can be specified in the constructor or by calling
// addInitiatorPorts.
//
// This component both implements MemoryIF and provides an export, so we
// can either connect by doing "memoryPort <= memory.targetExport;" in the
// connect phase or by doing "memoryPort.implementedBy( memory );" in the
// constructor
//
// If the read or write address map is not in the address map, then a
// RouterDecodeError will be thrown.
//
// Overlapping Address maps are decoded on a 'first in list wins' basis.
//
class Router extends Module implements MemoryIF
{
  late final MemoryPort targetExport;

  // this has to be fixed by the end of the construction phase.
  final List<(int,int,MemoryPort)> _initiatorPorts = [];

  Router( super.name , super.parent , [ List<(int,int,String)> initiatorDescription = const[] ] )
  {
    targetExport = MemoryPort('targetPort',this);
    addInitiatorPorts( initiatorDescription );

    targetExport.implementedBy( this );
  }

  void addInitiatorPorts( List<(int,int,String)> initiatorDescription )
  {
    for( var d in initiatorDescription )
    {
      int startAddress , endAddress;
      String portName;

      ( startAddress , endAddress , portName ) = d;
      _initiatorPorts.add( (startAddress , endAddress , MemoryPort( portName , this )) );
    }
  }

  MemoryPort initiatorPort( String portName )
  {
    int startAddress , endAddress;
    MemoryPort memoryPort;

    ( startAddress , endAddress , memoryPort ) = _initiatorPorts.firstWhere( (r) {
      int localStartAddress , localEndAddress;
      MemoryPort localMemoryPort;

      ( localStartAddress , localEndAddress , localMemoryPort ) = r;

      localStartAddress;
      localEndAddress;

      return localMemoryPort.name == portName;
    });

    startAddress;
    endAddress;

    return memoryPort;
  }

  @override
  Future<int> read( int addr ) async
  {
    int startAddress , endAddress;
    MemoryPort memoryPort;

    try
    {
      ( startAddress , endAddress , memoryPort ) = _initiatorPorts.firstWhere( (r) { return inRange( addr , r ); });
    }
    catch( e )
    {
      throw RouterDecodeError( fullName , 'Read' , addr );
    }

    (startAddress,endAddress);
    return await memoryPort.read( addr - startAddress );
  }

  @override
  Future<void> write( int addr , int data ) async
  {
    int startAddress , endAddress;
    MemoryPort memoryPort;

    try
    {
      ( startAddress , endAddress , memoryPort ) = _initiatorPorts.firstWhere( (r) { return inRange( addr , r ); });
    }
    catch( e )
    {
      throw RouterDecodeError( fullName , 'Write' , addr );
    }

    (startAddress,endAddress);
    await memoryPort.write( addr - startAddress , data );
  }

  bool inRange( int addr , (int,int,MemoryPort) r )
  {
    int startAddress , endAddress;
    MemoryPort memoryPort;

    ( startAddress , endAddress , memoryPort ) = r;

    memoryPort;
    return startAddress <= addr && addr < endAddress;
  }
}

class RouterDecodeError implements Exception
{
  final String routerName;
  final String command;
  final int addr;

  RouterDecodeError( this.routerName , this.command , this.addr );

  @override
  String toString()
  {
    return '$routerName Cannot Decode $command 0x$addr.toRadixString(16)';
  }
}
