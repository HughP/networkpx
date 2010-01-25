// migserver 

#include <idc.idc>

static functionize (ea) {
	auto is_thumb, head_ea, ea_flags;
	is_thumb = ea & 1;
	ea = ea & ~1;
	ea_flags = GetFlags(ea);
	if (!isCode(ea_flags) || GetReg(ea, "T") != is_thumb) {
		head_ea = !isHead(ea_flags) ? PrevHead(ea, 0) : ea;
		MakeUnkn(head_ea, DOUNK_EXPAND);
		SetRegEx(ea, "T", is_thumb, SR_autostart);
		MakeCode(ea);
	}
	MakeFunction(ea, BADADDR);
}

static seek_impl (ea, i) {
	auto fend, flags, mnem, op, target;
	fend = FindFuncEnd(ea);
	while (ea != BADADDR) {
		flags = GetFlags(ea);
		if (isCode(flags)) {
			mnem = GetMnem(ea);
			if (mnem == "BL" || mnem == "bl") {
				op = GetOpnd(ea, 0);
				if (op != "_memcpy") {
					target = LocByName(op);
					MakeFunction(target, BADADDR);
					MakeComm(target, form("MIG subsystem message #%d", i));
					return target;
				}
			}
		}
		ea = NextHead(ea, fend);
	}
}

static main () {
	auto ea, seg, const_seg, start, end, i, stub, argc, sa;
	
	ea = ScreenEA();
	if (SegName(ea) != "__const") {
		if (AskYN(0, "MIG subsystem declaration should appear in __TEXT,__const section. Continue?") != 1) {
			return;
		}
	}
	
	functionize(Dword(ea));
	start = Dword(ea + 4);
	end = Dword(ea + 8);
	for (i = ea; i < 24*(end-start)+ea+20; i = i + 4) {
		MakeDword(i);
		OpDec(i);
	}
	OpOff(ea, 0, 0);
	MakeStruct(ea, "mig_subsystem");
	
	ea = ea + 20;
	for (i = start; i < end; ++ i) {
		OpOff(ea+4, 0, 0);
		MakeStruct(ea, "routine_descriptor");
		stub = Dword(ea + 4);
		argc = Dword(ea + 8);
		functionize(stub);
		sa = seek_impl(stub, i);
		MakeComm(ea + 4, form("Impl #%d: 0x%x (%s)", i, sa, Name(sa)));
		ea = ea + 24;
	}
}