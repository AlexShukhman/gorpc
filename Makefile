build_protobufs:
	@echo "Building protobufs"	
	protoc -I=${PWD} --go_out=. --go_opt=paths=source_relative --go_out=${PWD}/build/proto ${PWD}/proto/app.proto

all: build_protobufs