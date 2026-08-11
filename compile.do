if {![file exists work]} {
	vlib work
}

vmap work work

do src/compile.do
