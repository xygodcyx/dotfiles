local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
	-- formatoff
	s("formatoff", {
		t({ "// clang-format off", "" }),
		i(1),
		t({ "", "// clang-format on", "" }),
	}),

	-- cout log
	s("coutt", {
		t("std::cout << "),
		i(1),
		t(" << std::endl;"),
	}),

	-- if
	s("if", {
		t("if ("),
		i(1),
		t({ ") {", "\t" }),
		i(2),
		t({ "", "}" }),
	}),

	-- for
	s("for", {
		t("for (int "),
		i(1, "i"),
		t(" = 0; "),
		t({ "i < " }), -- using the same node or reference
		i(2, "length"),
		t("; "),
		t({ "++" }),
		t("i) {"),
		t({ "", "\t" }),
		i(3),
		t({ "", "}" }),
	}),

	-- forin (range-based for)
	s("forin", {
		t("for (auto "),
		i(1, "value"),
		t(" : "),
		i(2, "itor"),
		t({ ") {", "\t" }),
		i(3),
		t({ "", "}" }),
	}),

	-- while
	s("while", {
		t("while ("),
		i(1),
		t({ ") {", "\t" }),
		i(3),
		t({ "", "}" }),
	}),

	-- switch
	s("switch", {
		t("switch ("),
		i(1),
		t({ ") {", "\t" }),
		i(2),
		t({ "", "}" }),
	}),

	-- function (fvoid)
	s("fvoid", {
		i(1, "void"),
		t(" "),
		i(2, "name"),
		t(" ( "),
		i(3),
		t({ " ) {", "\t" }),
		i(4),
		t({ "", "}" }),
	}),

	-- class
	s("class", {
		t("class "),
		i(1),
		t({ " {", "\t" }),
		i(2),
		t({ "", "};" }),
	}),

	-- struct
	s("struct", {
		t("struct "),
		i(1),
		t({ " {", "\t" }),
		i(2),
		t({ "", "};" }),
	}),
}
