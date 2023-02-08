all: Compliance

clean:
	-rm ./compliance

Compliance:
	env CGO_ENABLED=0 go build -o compliance -buildvcs=false -v .

.PHONY: clean