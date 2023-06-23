all: compliance

clean:
	-rm ./compliance

compliance:
	env CGO_ENABLED=0 go build -o compliance -buildvcs=false -v .

.PHONY: clean
