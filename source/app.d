module main;
import core.thread;
import std.stdio;
import std.bitmanip;
import std.range.primitives : empty;


import baos;
import object_server;

const ushort MAX_DATAPOINT_NUM = 1000;
ushort SI_currentBufferSize;

void main()
{
  auto baos = new Baos();

  auto serverItemMessage = baos.GetServerItemReq(1, 17);

  // maximum buffer size
  SI_currentBufferSize = 0;
  if (serverItemMessage.service == ObjServerServices.GetServerItemRes) {
    writeln("server items: good");
    foreach(ObjServerServerItem si; serverItemMessage.server_items) {
      writeln(si);
      // maximum buffer size
      if (si.id == 14) {
        SI_currentBufferSize = si.value.read!ushort();
        writeln("Current buffer size: ", SI_currentBufferSize);
      }
    }
  }
  /***
    if (datapointValueMessage.service == ObjServerServices.GetDatapointValueRes) {
    writeln("values: good");
    foreach(ObjServerDatapointValue dv; datapointValueMessage.datapoint_values) {
    writeln(dv);
    }
    }
   ***/
  // TODO: calculate max num of dps

  // GetDatapointDescriptionRes has a header(6b) and 5bytes each dp
  ushort number = cast(ushort)(SI_currentBufferSize - 6)/5;
  ushort start = 1;
  while(start < MAX_DATAPOINT_NUM ) {
    if (MAX_DATAPOINT_NUM - start <= number) {
      number = cast(ushort) (MAX_DATAPOINT_NUM - start + 1);
    }
    writeln("start-number: ", start, "-", number);
    auto descr = baos.GetDatapointDescriptionReq(start, number);
    if (descr.success) {
      writeln("descriptions: good", descr.datapoint_descriptions);
      foreach(ObjServerDatapointDescription dd; descr.datapoint_descriptions) {
        writeln(dd.id, "[", dd.type, "] ");
      }
    } else {
      writeln("error ocurred: ", descr.error.message);
    }
    start += number;
  }


  // process incoming values
  while(true) {
    ObjectServerMessage ind = baos.processInd();
    if (ind.service != ObjServerServices.unknown) {
      writeln("here comes message[ind]: ");
      // example
      foreach(ObjServerDatapointValue dv; ind.datapoint_values) {
        /****
          if (dv.id == 10) {
          ObjServerDatapointValue[] newVal;
          newVal.length = 1;
          newVal[0].id = 11;
          newVal[0].value.length = 1;
          newVal[0].value[0] = dv.value[0] == 0? 32: 8;
          writeln("new val: ", newVal[0].value[0]);
          Thread.sleep(1.msecs);
          baos.SetDatapointValueReq(cast(ushort) 10, newVal);
          } ****/
        writeln("#d ", dv.id, "=", dv.value);
      }
    }
    Thread.sleep(1.msecs);
    // process redis messages here?
    // TODO: simple messages as a model; test
  }
}
