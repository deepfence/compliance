all: Compliance

clean:
	-rm ./compliance

Compliance:
	go build -o compliance -buildvcs=false -v .

.PHONY: clean