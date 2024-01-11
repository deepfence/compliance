all: compliance

clean:
	-rm ./compliance

compliance:
	env CGO_ENABLED=0 go mod download golang.org/x/sys && go build -o compliance -buildvcs=false -v .

.PHONY: clean
