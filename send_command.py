import lldb
import asyncio

def send_visual(debugger, var_name, result, internal_dict):
    debugger = lldb.debugger.GetCommandInterpreter()
    output = expr(debugger, """import Darwin
let _data = try JSONEncoder().encode({name})
let _string = String(data: _data, encoding: .utf8)!
let _type: Any.Type = type(of: {name})
let _pointer = UnsafeRawPointer(bitPattern: unsafeBitCast(_type, to: Int.self))
var _info = Dl_info()
dladdr(_pointer, &_info)
let _fileName = String(cString: _info.dli_fname)
let _mangledName = String(cString: _info.dli_sname)
_fileName + "," + _mangledName + "," + _string
        """.format(name=var_name))
    asyncio.run(send(output))


def expr(debugger, cmd):
    cmd = 'po ' + ';'.join(cmd.split('\n')) # unclear if this is necessary, but was the only way I could get it to work
    result = lldb.SBCommandReturnObject()
    debugger.HandleCommand(cmd, result)
    if result.Succeeded():
        return result.GetOutput()
    else:
        print(result.GetError())
        raise

async def send(message):
    _, writer = await asyncio.open_connection('localhost', 7001)
    writer.write(message.encode())

def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command script add -f send_command.send_visual send_visual')
    print('The "send_visual" python command has been installed and is ready for use.')
