$(document).ready(function(){

  // Betting check
  $('#place-bet').prop('disabled', true);
  $('#bet').keyup(function(){
    $('#place-bet').prop('disabled', parseInt(this.value) > 0 ? false : true)
  });

  $(document).on('click','#hit_form button', function(){
    $.ajax({
      type: 'POST',
      url: '/play/player/hit'
    }).done(function(msg){
      $('#play').replaceWith(msg);
    });
    return false
  });

  $(document).on('click','#stay_form button', function(){
    $.ajax({
      type: 'POST',
      url: '/play/player/stay'
    }).done(function(msg){
      $('#play').replaceWith(msg);
    });
    return false
  });

  $(document).on('click','#dealer_form button', function(){
    $.ajax({
      type: 'POST',
      url: '/play/dealer/hit'
    }).done(function(msg){
      $('#play').replaceWith(msg);
    });
    return false
  });

});