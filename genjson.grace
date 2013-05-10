import "mgcollections" as collections

method wrap(v) {
    match(v)
        case { _ : String -> JSString.new(v) }
        case { _ -> v }
}
class JSObj.new {
    def data = collections.map.new
    method put(key, val) {
        data.put(key, wrap(val))
    }
    method asJSON {
        var ret := "\{"
        for (data) do {k->
            ret := ret ++ "\"{k}\": " ++ data.get(k).asJSON ++ ","
        }
        return ret ++ "}"
    }
}

class JSArray.new {
    def data = collections.list.new
    method push(val) {
        data.push(wrap(val))
    }
    method asJSON {
        var ret := "["
        for (data) do {v->
            ret := ret ++ v.asJSON ++ ","
        }
        return ret ++ "]"
    }
}

class JSString.new(s) {
    def data = s
    method asJSON {
        return "\"{data}\""
    }
}

method generateNode(n) {
    def ret = JSObj.new
    match (n.kind)
        case { "vardec" ->
            ret.put("type", "vardec")
            ret.put("name", n.name.value)
            ret.put("value", generateNode(n.value))
        } case { "string" ->
            ret.put("type", "string")
            ret.put("value", n.value)
        } case { "num" ->
            ret.put("type", "number")
            ret.put("value", n.value)
        } case { "op" ->
            ret.put("type", "operator")
            ret.put("left", generateNode(n.left))
            ret.put("right", generateNode(n.right))
            ret.put("operator", n.value)
        } case { "bind" ->
            if (n.dest.kind == "member") then {
                if (n.dest.in.value == "prelude") then {
                    ret.put("type", "dialect-request")
                    ret.put("value", generateNode(n.value))
                    ret.put("name", n.dest.value ++ ":=")
                } else {
                    ret.put("type", "unknown assign")
                }
            } else {
                ret.put("type", "assign")
                ret.put("left", generateNode(n.dest))
                ret.put("right", generateNode(n.value))
            }
        } case { "method" ->
            ret.put("type", "method")
            ret.put("name", n.value.value)
            ret.put("arg", n.signature.at(1).params.at(1).value)
            def body = JSArray.new
            for (n.body) do {v->
                body.push(generateNode(v))
            }
            ret.put("body", body)
        } case { "identifier" ->
            ret.put("type", "var")
            ret.put("value", n.value)
        } case { "call" ->
            if (n.value.kind == "member") then {
                if (n.value.in.value == "prelude") then {
                    if (n.with.at(1).args.size == 0) then {
                        ret.put("type", "constant")
                        ret.put("name", n.value.value)
                    } else {
                        def arg = generateNode(n.with.at(1).args.at(1))
                        if (n.value.value == "print") then {
                            ret.put("type", "print")
                            ret.put("value", arg)
                        } else {
                            ret.put("type", "dialect-request")
                            ret.put("name", n.value.value)
                            ret.put("value", arg)
                        }
                    }
                } else {
                    if (n.value.in.value == "self") then {
                        def arg = generateNode(n.with.at(1).args.at(1))
                        ret.put("type", "selfcall")
                        ret.put("argument", arg)
                        ret.put("name", n.value.value)
                    } else {
                        ret.put("type", "request")
                        ret.put("receiver", generateNode(n.value.in))
                        ret.put("name", n.value.value)
                    }
                }
            } else {
                ret.put("type", "unknown call")
                print "    {n.pretty(4)}"
            }
        } case { _ ->
            ret.put("type", "UNKNOWN")
            ret.put("internalKind", n.kind)
        }
    return ret
}

method generate(values, outfile) {
    def overall = JSObj.new
    def arr = JSArray.new
    overall.put("chunks", arr)
    def chunk = JSObj.new
    arr.push(chunk)
    chunk.put("type", "chunk")
    chunk.put("x", "10px")
    chunk.put("y", "10px")
    def body = JSArray.new
    chunk.put("body", body)
    for (values) do {v->
        if (v.kind == "dialect") then {
            overall.put("dialect", v.value)
        } else {
            body.push(generateNode(v))
        }
    }
    outfile.write(overall.asJSON ++ "\n")
}
