FROM ibmcom/swift-ubuntu

RUN apt-get update -y && apt-get install -y curl
WORKDIR /maze-api
ADD / .
RUN swift build

CMD sleep 10 \
    && curl -X PUT http://couch:5984/_users \
    && ./.build/x86_64-unknown-linux/debug/MazeApi
