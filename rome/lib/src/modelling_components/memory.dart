/*
Copyright 2024 Adam Rose

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import '../modelling.dart';
import '../simulator.dart';

abstract interface class MemoryIF
{
  Future<void> write( int addr , int data );
  Future<int> read( int addr );
}

//
// This is a simple memory using 64(ish) bit address and data.
//
// It has an export and implements the interface, to enable either <= or
// 'implementedBy' style connectivity.
//
// If the address is larger than the size, it will throw a RangeError
//

class MemoryPort extends Port<MemoryIF> implements MemoryIF
{
  MemoryPort( super.name , [super.parent] );
}

class Memory extends Module implements MemoryIF
{
  late final Port<MemoryIF> memoryExport;
  late final List<int> _memory;
  final int? delay;

  Memory( super.name , super.parent , int size , {this.delay = 10 , int fill = -1} )
  {
    memoryExport = Port('memoryExport' , this );
    _memory = List<int>.filled( size , fill );

    memoryExport.implementedBy( this );
  }

  @override
  Future<int> read( int addr ) async
  {
    if( delay != null ) await( scheduler.delay( delay! ) );

    int d;

    try
    {
      d = _memory[addr];
    }
    on RangeError
    {
      mPrint('Cannot read from address 0x${addr.toRadixString(16)} because memory is [${0x0}:0x${_memory.length.toRadixString(16)})');
      rethrow;
    }

    mPrint('just read 0x${d.toRadixString(16)} from 0x${addr.toRadixString(16)}');
    return d;
  }

  @override
  Future<void> write( int addr , int data ) async
  {
    if( delay != null ) await( scheduler.delay( delay! ) );
    try
    {
      _memory[addr] = data;
    }
    on RangeError
    {
      mPrint('Cannot write 0x$data.toRadixString(16) to address 0x$addr.toRadixString(16) because memory is [0x0:0x$_memory.length.toRadixString(16))]');
      rethrow;
    }
    mPrint('just wrote 0x${data.toRadixString(16)} to 0x${addr.toRadixString(16)}');

  }
}
