#!/bin/bash

# Javascript Experiments
echo "Experimenting on Node.js v15.14.0"
docker build -f javascript/Dockerfile.NodeV15_14_0 -t node-v15.14.0-regex .
docker run --volume $PWD/javascript/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm node-v15.14.0-regex
docker rmi node-v15.14.0-regex

echo "Experimenting on Node.js v22.2.0"
docker build -f javascript/Dockerfile.NodeV22_2_0 -t node-v22.2.0-regex .
docker run --volume $PWD/javascript/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm node-v22.2.0-regex
docker rmi node-v22.2.0-regex

# Ruby Experiments
echo "Experimenting on Ruby v3.1.6"
docker build -f ruby/Dockerfile.RubyV3_1_6 -t ruby-v3.1.6-regex .
docker run --volume $PWD/ruby/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm ruby-v3.1.6-regex
docker rmi ruby-v3.1.6-regex

echo "Experimenting on Ruby v3.3.2"
docker build -f ruby/Dockerfile.RubyV3_3_2 -t ruby-v3.3.2-regex .
docker run --volume $PWD/ruby/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm ruby-v3.3.2-regex
docker rmi ruby-v3.3.2-regex

# C# Experiments
echo "Experimenting on .NET 6.0.420"
docker build -f c#/Dockerfile.NetV6_0_420 -t net-v6.0.420-regex .
docker run --volume $PWD/c#/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm net-v6.0.420-regex
docker rmi net-v6.0.420-regex

echo "Experimenting on .NET 7.0.407"
docker build -f c#/Dockerfile.NetV7_0_407 -t net-v7.0.407-regex .
docker run --volume $PWD/c#/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm net-v7.0.407-regex
docker rmi net-v7.0.407-regex

# Perl Experiments
echo "Experimenting on Perl v5.18.4"
docker build -f perl/Dockerfile.PerlV5_18_4 -t perl-v5.18.4-regex .
docker run --volume $PWD/perl/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm perl-v5.18.4-regex
docker rmi perl-v5.18.4-regex

echo "Experimenting on Perl v5.38.2"
docker build -f perl/Dockerfile.PerlV5_38_2 -t perl-v5.38.2-regex .
docker run --volume $PWD/perl/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm perl-v5.38.2-regex
docker rmi perl-v5.38.2-regex

# Go Experiments
echo "Experimenting on Go 1.5.4"
docker build -f go/Dockerfile.Go1_5_4 -t go-1.5.4-regex .
docker run --volume $PWD/go/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm go-1.5.4-regex
docker rmi go-1.5.4-regex

echo "Experimenting on Go 1.22.4"
docker build -f go/Dockerfile.Go1_22_4 -t go-1.22.4-regex .
docker run --volume $PWD/go/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm go-1.22.4-regex
docker rmi go-1.22.4-regex

# Python Experiments
echo "Experimenting on Python 3.6"
docker build -f python/Dockerfile.Python3_6 -t python-3.6-regex .
docker run --volume $PWD/python/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm python-3.6-regex
docker rmi python-3.6-regex

echo "Experimenting on Python 3.12"
docker build -f python/Dockerfile.Python3_12 -t python-3.12-regex .
docker run --volume $PWD/python/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm python-3.12-regex
docker rmi python-3.12-regex

# Rust Experiments
echo "Experimenting on Rust 1.12.1"
docker build -f rust/Dockerfile.Rust1_12_1 -t rust-1.12.1-regex .
docker run --volume $PWD/rust/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm rust-1.12.1-regex
docker rmi rust-1.12.1-regex

echo "Experimenting on Rust 1.78.0"
docker build -f rust/Dockerfile.Rust1_78_0 -t rust-1.78.0-regex .
docker run --volume $PWD/rust/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm rust-1.78.0-regex
docker rmi rust-1.78.0-regex

# Java Experiments
echo "Experimenting on Java 8"
docker build -f java/Dockerfile.Java8 -t java-8-regex .
docker run --volume $PWD/java/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm java-8-regex
docker rmi java-8-regex

echo "Experimenting on Java 23"
docker build -f java/Dockerfile.Java23 -t java-23-regex .
docker run --volume $PWD/java/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm java-23-regex
docker rmi java-23-regex

# PHP Experiments
echo "Experimenting on PHP 5.6"
docker build -f php/Dockerfile.PHP5_6 -t php-5.6-regex .
docker run --volume $PWD/php/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm php-5.6-regex
docker rmi php-5.6-regex

echo "Experimenting on PHP 8.3"
docker build -f php/Dockerfile.PHP8_3 -t php-8.3-regex .
docker run --volume $PWD/php/results:/usr/src/app/results --volume $PWD/../sl-regex-corpus/sampled:/usr/src/app/dataset -d --rm php-8.3-regex
docker rmi php-8.3-regex
