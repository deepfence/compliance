all: Compliance

clean:
	-rm ./compliance

Compliance:
	go build -o compliance

.PHONY: clean