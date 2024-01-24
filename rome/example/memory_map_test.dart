/*
Copyright 2024 Adam Rose

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'package:rome/rome.dart';

List<(int,int,String)> memoryMap = [
  (0x000,0x100,'memPortA') ,
  (0x100,0x200,'memPortB') ,
  (0x400,0x500,'memPortC')
];

class Top extends Module
{
  late final Initiator initiator;
  late final Router router;
  late final Memory memoryA , memoryB , memoryC;

  Top( super.name , [super.parent] )
  {
    initiator = Initiator('initiator',this);
    router = Router('router',this,memoryMap);

    memoryA = Memory('memoryA',this,0x100);
    memoryB = Memory('memoryB',this,0x100);
    memoryC = Memory('memoryC',this,0x100);
  }

  @override
  void connect()
  {
    initiator.memoryPort <= router.targetExport;

    router.initiatorPort('memPortA') <= memoryA.memoryExport;
    router.initiatorPort('memPortB') <= memoryB.memoryExport;
    router.initiatorPort('memPortC') <= memoryC.memoryExport;
  }
}

class Initiator extends Module
{
  late final MemoryPort memoryPort;

  Initiator( super.name , [super.parent] )
  {
    memoryPort = MemoryPort('memoryPort',this);
  }

  @override
  void run() async
  {
    await memoryPort.write( 0xff , 0xff );
    await memoryPort.read( 0xff );

    await memoryPort.write( 0x100 , 0x100 );
    await memoryPort.read( 0x100 );

    await memoryPort.write( 0x405 , 0x405 );
    await memoryPort.read( 0x405 );

    try
    {
      await memoryPort.write( 0x505 , 0 );
    }
    on RouterDecodeError catch( e )
    {
      print('expected Error $e');
    }
  }
}

void main() {
  Top top = Top('top');

  simulate( top );
}
