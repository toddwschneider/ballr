$(function() {
  $(document).on("click", ".download-shot-chart", function(e) {
    e.preventDefault();
    var filename = $(this).data("filename");

    html2canvas($(".shot-chart-container"), {
      onrendered: function (canvas) {
        var a = document.createElement("a");
        a.href = canvas.toDataURL("image/png").replace("image/png", "image/octet-stream");
        a.download = filename;
        a.click();
      }
    });
  });

  $("#player_name").selectize({
    selectOnTab: true,
    maxOptions: 5000,
    onDropdownOpen: function() {
      this.clear('silent');
    }
  });

  $("#shot_zone_basic_filter").attr("title", "Filter shot zones...");
  $("#shot_zone_angle_filter").attr("title", "Filter shot angles...");
  $("#shot_distance_filter").attr("title", "Filter shot distances...");

  $("#shot_zone_basic_filter, #shot_zone_angle_filter, #shot_distance_filter").selectpicker();
});
