FROM public.ecr.aws/c1t8q5x5/fedcli@sha256:d63a4ef714b0653bf20e0c9aa9d8e6df2c979397e3a52024ee098ba12ce2484d

USER root

COPY entrypoint.sh /opt/fedcli-action/entrypoint.sh

RUN chmod 0555 /opt/fedcli-action/entrypoint.sh \
    && chown 10001:10001 /opt/fedcli-action/entrypoint.sh

USER 10001:10001

ENTRYPOINT ["/opt/fedcli-action/entrypoint.sh"]
