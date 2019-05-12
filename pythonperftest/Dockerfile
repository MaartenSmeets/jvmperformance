FROM python:3

WORKDIR /usr/src/app

ENV URL http://9292ov.nl
ENV LOGFILEDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENTRYPOINT ["python","./perftest.py"]
