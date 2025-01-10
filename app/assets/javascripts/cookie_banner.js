document.addEventListener("turbolinks:load", function () {
  const banner = document.getElementById("cookie-banner");
  const acceptButton = document.getElementById("accept-cookies");

  if (!document.cookie.includes("cookies_accepted=true")) {
    banner.style.display = "block";
  }

  acceptButton.addEventListener("click", function () {
    fetch("/cookies/accept", {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")
          .content,
      },
    }).then(function () {
      banner.style.display = "none";
    });
  });
});
