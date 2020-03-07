import lldb
import asyncio

def send_visual(debugger, var_name, result, internal_dict):
    cmd = 'expr try JSONEncoder().encode(' + var_name + ')'
    debugger = lldb.debugger.GetCommandInterpreter()
    result = lldb.SBCommandReturnObject()
    debugger.HandleCommand(cmd, result)
    if result.Succeeded():
        output = result.GetOutput()
        print(output)
        if output.startswith('(Data) '):
            var_name = output[7:11]
            cmd = 'po String(data: ' + var_name + ', encoding: .utf8)!'
            debugger.HandleCommand(cmd, result)
            if result.Succeeded():
                output = result.GetOutput()
                asyncio.run(send(output))
            else:
                print(result.GetError())
    else:
        print(result.GetError())


async def send(message):
    _, writer = await asyncio.open_connection('localhost', 7000)
    writer.write(message.encode())

def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command script add -f send_command.send_visual send_visual')
    print('The "send_visual" python command has been installed and is ready for use.')
