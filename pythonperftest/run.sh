docker run --name perftest -v "$(pwd)"/logs:/logs -e URL=https://www.google.com -e LOGFILEDIR=/logs perftest
