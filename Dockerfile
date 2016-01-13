FROM trenpixster/elixir

ADD sosba /sosba
WORKDIR /sosba

ENV MIX_ENV prod
ENV ELIXIR_ERL_OPTIONS "-mnesia dir './data/'"

RUN mix local.rebar
RUN mix local.hex --force
RUN mix hex.info
#RUN mix hex.update

RUN mix deps.get 
RUN mix deps.compile
RUN mix compile
CMD ["mix", "run", "--no-deps-check", "--no-compile", "--no-halt"]
