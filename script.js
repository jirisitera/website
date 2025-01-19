
setTimeout(header, 1);

let lastVisible = true;

function header() {
  const stationary_header = document.getElementById('stationary-header');
  const sticky_header = document.getElementById('sticky-header');
  window.onscroll = function () {
    const visibility = checkVisible(stationary_header);
    if (lastVisible === visibility) {
      return;
    }
    sticky_header.style.animation = visibility ? "disappear 0.25s ease forwards" : "appear 0.25s ease forwards";
    lastVisible = visibility;
  };
}
function checkVisible(element) {
  const rect = element.getBoundingClientRect();
  const viewHeight = Math.max(document.documentElement.clientHeight, window.innerHeight);
  return !(rect.bottom < 1 || rect.top - viewHeight >= 1);
}
