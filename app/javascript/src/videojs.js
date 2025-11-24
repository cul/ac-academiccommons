import videojs from "video.js";

const Component = videojs.getComponent("Component");

class Logo extends Component {
  constructor(player, options = {}) {
    super(player, options);
  }
  createEl() {
    const link = this.options().logo.link
    const img = videojs.dom.createEl("img", this.options().logo);
    const componentElement = videojs.dom.createEl("div", {
      className: "vjs-logo",
    });

    if (link) {
      componentElement.addEventListener('click', (function () {
        window.open(link, '_blank')
      }));
    }

    videojs.dom.appendContent(componentElement, img);
    return componentElement;
  }
};
videojs.registerComponent("Logo", Logo);

const knownVideoJsPlayers = new Map();

window.getVideoJsPlayerForElement = (element) => {
  return knownVideoJsPlayers.get(element);
};

const setVideoJsPlayerForElement = (element, videoJsPlayer) => {
  return knownVideoJsPlayers.set(element, videoJsPlayer);
};

export const videoReady = function () {
  const $showPageAudioVideoElements = $("video, audio");
  if ($showPageAudioVideoElements.length > 0) {
    $showPageAudioVideoElements.each(function (_ix, el) {

      const player = videojs(el);

      if (el.attributes['player-logo']) {
        player.addChild("Logo", {
          logo: {
            src: el.attributes["player-logo"].value, link: el.attributes['data-brand-link'].value
          },
        });
      }
      setVideoJsPlayerForElement(el, player);
    });
  }
};
