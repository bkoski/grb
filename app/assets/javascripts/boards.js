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

  $('.issues:not(.not-sortable)').sortable({
    items: '.issue',
    update: function(e, ui) { updateItemSort(ui.item); }
  });

  $('.completed-work-toggle').click(function(e) {
    e.preventDefault();
    $('.container').removeClass('hide-completed-work');
    $(e.currentTarget).hide();
  })

  $(document).on('click', '.commits .show-more button', function(e) {
    e.preventDefault();
    $(e.currentTarget).closest('.commits').find('.commit').removeClass('hidden');
    $(e.currentTarget).hide();
  });
});

/****************************/
/* #reassign-modal handling */
/****************************/

$(document).on('click', '.reassign-modal-trigger', function(e) {
  var currentOffset = $(e.currentTarget).offset();
  var issueId       = $(e.currentTarget).closest('.issue').data('object-id');

  $('#container').css({'position' : 'relative'})
  $('#reassign-modal').addClass('active').css({
    top: currentOffset.top + $(e.currentTarget).height(),
    left: currentOffset.left - $('#reassign-modal').width() + $(e.currentTarget).width()
  });
  $('#reassign-modal').data('object-id', issueId);

  e.stopPropagation();
});

// dismiss modal by clicking outside
$(document).on('click', function(e) {
  if(!$(e.currentTarget).hasClass('reassign-modal-trigger') && $('#reassign-modal').is(':visible') && $(e.target).closest('#reassign-modal').length == 0) {
    $('#reassign-modal').removeClass('active');
  }
});

// handle click on #reassign-modal avatar
$(document).on('click', '#reassign-modal .milestone-contributor', function(e) {
  updateIssue($('#reassign-modal').data('object-id'), { assignee: $(e.currentTarget).data('contributor') });
  $('#reassign-modal').removeClass('active');
});

// select item in Someone else... dropdown
$(document).on('change', '#reassign-modal select', function(e) {
  updateIssue($('#reassign-modal').data('object-id'), { assignee: $('#reassign-modal select').val() });
});

// init Someone else... dropdown
$(document).ready(function() {
  $('#reassign-modal select').material_select();
});