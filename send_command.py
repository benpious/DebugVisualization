import lldb

def send_visual(debugger, var_name):
    cmd = 'expr try JSONEncoder().encode(' + var_name + ')'
    result =  lldb.SBCommandReturnObject()
    lldb.debugger.HandleCommand(cmd, result)
    if result.Succeeded():
        output = result.getOutput()
        if output.startswith('(Data) '):
            var_name = output[7:3]
            cmd = 'po String(data: ' + var_name + ', encoding: .utf8)!'
            lldb.debugger.HandleCommand(cmd, result)
            if result.Succeeded():
                output = result.getOutput()
            else:
                print("fucked")
    else:
        print("fucked")
