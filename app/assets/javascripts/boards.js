// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function updateIssue(issueId, update) {
  $.ajax("/issues/" + issueId, {
    method: "PUT",
    data: update,
    error: function() { alert('Save failed!') },
    success: function() { console.log('ok'); }
  });  
}

$(document).ready(function() {
  $('.issues').on('click', '.action', function(e) {
    var target = $(e.currentTarget);
    updateIssue(target.closest('.issue').data('object-id'), { status: target.data('status') });
  });

  $('.issues').sortable({
    items: '.issue',
    update: function(e, ui) { updateItemSort(ui.item); }
  });
});