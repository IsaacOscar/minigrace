dialect "standard"
import "gUnit" as gu
inherit gu.assertion

method countOneAssertion {
    print "one assertion in module"
}

method b { "this is b" }

def o = object {
    inherit gu.assertion
    method countOneAssertion {
        print "one assertion in o"
    }
    method d { "this is d" }

    self.assert( 1 == 1 )
}

print(b)
assert(true)
print(o.d)
print "done"
