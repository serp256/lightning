
all:
	$(MAKE) -C src

install: 
	$(OCAMLFIND) install lightning META lightning/lightning.cmxa lightning/lightning.a lightning/*.cmi lightning/*.mli 

clean: 
	$(MAKE) -C src clean

