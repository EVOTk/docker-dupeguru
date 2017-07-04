#
# dupeguru Dockerfile
#
# https://github.com/jlesage/docker-dupeguru
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-v1.4.3

# Define software versions.
ARG DUPEGURU_VERSION=4.0.3

# Define software download URLs.
ARG DUPEGURU_URL=https://launchpad.net/~hsoft/+archive/ubuntu/ppa/+files/dupeguru_${DUPEGURU_VERSION}~xenial_amd64.deb

# Define working directory.
WORKDIR /tmp

# Install dupeGuru.
RUN \
    # Install packages needed by the build.
    apk --no-cache add --virtual build-dependencies binutils curl patch && \

    # Download the dupeGuru package.
    echo "Downloading dupeGuru package..." && \
    curl -# -L -o dupeguru.deb ${DUPEGURU_URL} && \

    # Extract the dupeGuru package.
    ar vx dupeguru.deb && \
    tar xf data.tar.xz -C / && \

    # Fix for Python3.6 support.
    CPYTHON_LIBS="$(find /usr/share/dupeguru -name "*cpython-35m-x86_64*")" && \
    for LIB in $CPYTHON_LIBS; do \
        mv "$LIB" "$(echo "$LIB" | sed "s/cpython-35m-x86_64/cpython-36m-x86_64/")"; \
    done && \

    # Apply patch for os termination signals handling.
    cd /usr/share/dupeguru && \
    curl -# -L https://github.com/jlesage/dupeguru/commit/73dbacace18542e27260514b436c3b7f746fc203.patch | patch -p1 && \
    cd /tmp && \

    # Setup symbolic links for stuff that need to be outside the container.
    mkdir -p $HOME/.local/share/"Hardcoded Software" && \
    ln -s /config/share $HOME/.local/share/"Hardcoded Software"/dupeGuru && \
    ln -s /config/QtProject.conf $HOME/.config/QtProject.conf && \
    mkdir -p $HOME/.config/"Hardcoded Software" && \
    ln -s /config/dupeGuru.conf $HOME/.config/"Hardcoded Software"/dupeGuru.conf && \
    chown -R $USER_ID:$GROUP_ID $HOME && \

    # Enable direct file deletion by default.
    #sed -i 's/self.direct = False/self.direct = True/' /usr/share/dupeguru/core/gui/deletion_options.py && \

    # Maximize only the main/initial window.
    sed -i 's/<application type="normal">/<application type="normal" title="dupeGuru">/' \
        $HOME/.config/openbox/rc.xml && \

    # Make sure the main window is always in the background.
    sed -i '/<application type="normal" title="dupeGuru">/a \    <layer>below</layer>' \
        $HOME/.config/openbox/rc.xml && \

    # Make sure dialog windows are always above other ones.
    #sed -i 's|</applications>|    <application type="dialog">\n  <layer>above</layer>\n  </application>\n</applications>|' \
    sed -i '/<\/applications>/i \  <application type="dialog">\n    <layer>above<\/layer>\n  <\/application>' \
        $HOME/.config/openbox/rc.xml && \

    # Cleanup.
    apk --no-cache del build-dependencies && \
    rm -rf /tmp/*

# Install dependencies.
RUN apk --no-cache add \
        python3 \
        py3-qt5 \
        mesa-dri-swrast \
        dbus

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/dupeguru-icon.png && \
    /opt/install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="dupeGuru" \
    TRASH_DIR="/trash"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/trash"]

# Metadata.
LABEL \
      org.label-schema.name="dupeguru" \
      org.label-schema.description="Docker container for dupeGuru" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-dupeguru" \
      org.label-schema.schema-version="1.0"
