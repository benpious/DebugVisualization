import lldb
import asyncio

def send_visual(debugger, var_name, result, internal_dict):
    debugger = lldb.debugger.GetCommandInterpreter()
    output = expr(debugger, """import Darwin
let data = try JSONEncoder().encode({name})
let string = String(data: data, encoding: .utf8)!
let type: Any.Type = Swift.type(of: {name})
let pointer = UnsafeRawPointer(bitPattern: unsafeBitCast(type, to: Int.self))
var info = Dl_info()
dladdr(pointer, &info)
let fileName = String(cString: info.dli_fname)
let mangledName = String(cString: info.dli_sname)
"\(fileName), \(mangledName), \(string)"
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
    _, writer = await asyncio.open_connection('localhost', 7000)
    writer.write(message.encode())

def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command script add -f send_command.send_visual send_visual')
    print('The "send_visual" python command has been installed and is ready for use.')
