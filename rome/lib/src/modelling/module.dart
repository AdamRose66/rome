/*
Copyright 2024 Adam Rose

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'port.dart';

// named components have a parent, and can add themselves to its child list

class NamedComponent
{
  final String name;
  final Module? parent;

  String get fullName => parent == null ? name : '${parent!.fullName}.$name';

  NamedComponent( this.name , this.parent )
  {
    parent?.addChild( this );
  }

  void mPrint( String message , [String indent='  '] )
  {
    print('$indent$name: $message');
  }
}

// modules are NamedComponents that have children and phase methods

class Module extends NamedComponent
{
  var children = [];

  Module( super.name , [super.parent] );

  void addChild( NamedComponent child )
  {
    children.add( child );
  }

  void connect() {}

  void postConnect() {
    for( NamedComponent c in children )
    {
      if( c is PortBase )
      {
        if( c.isStartPort )
        {
          c.doConnections();
        }
      }
    }
  }

  void run() async {}
}

//
// we might need a synchronous version of this, but at the moment we only use
// it in the async simulate function ...
//
void visit( Module m , {void Function( Module)? topDown, void Function( Module)? bottomUp } ) async
{
  topDown?.call( m );
  for( NamedComponent c in m.children )
  {
    if( c is Module )
    {
      visit( c , topDown : topDown , bottomUp : bottomUp );
    }
  }
  bottomUp?.call( m );
}
