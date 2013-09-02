#define REG_CALLBACK(name) \
	value* name = NULL; \
	if (Is_block(v_##name)) { \
		name = (value*)malloc(sizeof(value)); \
		*name = Field(v_##name, 0); \
		caml_register_generational_global_root(name); \
	}

#define UNREG_CALLBACK(name) if (name) { caml_remove_generational_global_root(name); }
#define CALL(name,param) if (name) { caml_callback(*name, param); }