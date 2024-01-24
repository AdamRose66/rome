This is the ROME ( Rapid Object orientated Modeling Environment ). Its
immediate inspiration was Rohd, but it also uses ideas from SystemC,
SystemVerilog/UVM, and CoCoTB.

The idea is to take advantage of Dart's language capabilities to create a
modeling Environment for Digital Systems.

It may well be that the implementation is folded into Rohd at some point
in the not-too-distant future.

## Features

- an event driven scheduler using await, Future, and Completers.
- Hierarchical Modules
- module aware Ports ( ie, interface proxies ) that allow direct remote calling
of abstract interfaces across the module hierarchy

## Getting started

See the two exammples in the examples directory.

One is a simple consumer / producer arrangement talking across a fifo.
The is an initiator -> router -> target arrangement which mimics a simple
processor + memory architecture.

## Usage

Here is the asynchronous run method from the publisher in
examples/fifo_channel_example.dart:

```dart
void run() async
{
  Print('run');
  for( int i = 0; i < 10; i++ )
  {
    Print('about to put ${i}');
    await putPort.put( i );
    await Delay( 10 );
  }
}
'''

There are two asynchronous calls in the loop. The first waits until there is
room in the fifo attached to the putPort before completing. The second
interacts with the scheduler to wait 10 time units before continuing.

Here is the connect method from examples/memory_map_test.dart:

```dart
void connect()
{
  initiator.memoryPort <= router.targetExport;

  router.initiatorPort('memPortA') <= memoryA.memoryExport;
  router.initiatorPort('memPortB') <= memoryB.memoryExport;
  router.initiatorPort('memPortC') <= memoryC.memoryExport;
}
'''

The initiator ( aka master or processor model ) connects to the router, and
the router connects to each of the memories in this simple system. We use <= to
connect a Port that requires an interface to a Port that provides it.
