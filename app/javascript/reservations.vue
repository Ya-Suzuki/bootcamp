<template lang="pug">
  .reservations__outer
    .reservations
      .reservations__calender
        .reservations__calender-header
          .reservations__calender-header-label.is-day
            |
          .reservations__calender-header-label.is-seat(v-for="seat in seats" :key="seat.id" @click="createReservationForOneMonth(seat.id)")
            | {{ seat.name }}
          .reservations__calender-header-label.is-memo
            | メモ
        .reservations__day-items
          .reservations__day-item.date(v-for="one_day in this_months" v-bind:class="is_holiday(reservationsHolidayJps[one_day['ymd']])")
            .reservations__day-item-value.reservations__day.is-day(@click="createReservationForOneDay(one_day['ymd'])") {{ one_day['d_jp'] }}
            .reservations__day-item-value.reservations__seat.is-seat(v-for="seat in seats" :key="seat.id" v-bind:id="reservation_hash_id(one_day['ymd'],(seat.id))")
              #reserve-seat.reservations__seat-action(v-if="reservations[`${one_day['ymd']}-${seat.id}`] === undefined" @click="createReservation(one_day['ymd'], seat.id)")
                |
              reservation(v-else :currentUserId="currentUserId", :parentReservation="reservations[`${one_day['ymd']}-${seat.id}`]", @delete="deleteReservation")
            .reservations__day-item-value(v-if="admin_login == 1" v-bind:id="memoId(one_day['ymd'])").is-memo
              memo(:memo="memos[one_day['ymd']]" :date="one_day['ymd']")
            .reservations__day-item-value(v-else v-bind:id="memoId(one_day['ymd'])").is-memo
              template(v-if="memos[one_day['ymd']] === undefined")
                |
              template(v-else)
                | {{ memoBody(one_day) }}
</template>
<script>

import Reservation from './reservation.vue'
import Memo from './memo.vue'
import moment from 'moment'

moment.locale('ja');

export default {
  props: {
    reservationsBegginingOfThisMonth: String,
    reservationsEndOfThisMonth: String,
    currentUserId: String
  },
  components: {
    'reservation': Reservation,
    'memo': Memo
  },
  data: () => {
    return {
      this_months: [],
      reservation: [],
      reservations: {},
      seats: {},
      reservationsHolidayJps: {},
      memos: {},
      admin_login: ''
    }
  },
  created: function() {
    this.reservationsHolidayJps = JSON.parse(document.querySelector('#js-reservations-data-holiday-jps').innerText);
    this.memos = JSON.parse(document.querySelector('#js-memos-data').innerText);
    this.seats = JSON.parse(document.querySelector('#js-seats-data').innerText);

    if (!(document.querySelector('#js-admin-login') == null)) {
      this.admin_login = document.querySelector('#js-admin-login').innerText;
    }

    fetch(`/api/reservations.json?beggining_of_this_month=${this.reservationsBegginingOfThisMonth}&end_of_this_month=${this.reservationsEndOfThisMonth}`, {
      method: 'GET',
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
      },
      credentials: 'same-origin',
      redirect: 'manual'
    })
      .then(response => {
        return response.json()
      })
      .then(json => {
        json.forEach(c => {
          this.$set(this.reservations, `${c.date}-${c.seat_id}`, c);
        });
      })
      .catch(error => {
        console.warn('Failed to parsing', error)
      })

    this.this_months = this.getDates(
      new Date(this.reservationsBegginingOfThisMonth),
      new Date(this.reservationsEndOfThisMonth)
    );
  },
  methods: {
    token () {
      const meta = document.querySelector('meta[name="csrf-token"]')
      return meta ? meta.getAttribute('content') : ''
    },
    getDates: function(startDate, stopDate) {
      var dateArray = new Array();
      var currentDate = startDate;
      while (currentDate <= stopDate) {
          var one_day = {};
          one_day["ymd"] = moment(new Date (currentDate)).format("YYYY-MM-DD");
          one_day["d_jp"] = moment(new Date (currentDate)).format("D日(ddd)");
          dateArray.push( one_day );
          currentDate = moment(currentDate).add(1, 'd');
      }
      return dateArray;
    },
    createReservation: function(date, seat_id) {
      let params = {
        'seat_id': seat_id,
        'date': date,
      }
      fetch(`/api/reservations`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.token()
        },
        credentials: 'same-origin',
        redirect: 'manual',
        body: JSON.stringify(params)
      })
        .then(response => {
          return response.json();
        })
        .then(json => {
          if (Array.isArray(json)) {
            json.forEach(c => {
              this.$set(this.reservations, `${c.date}-${c.seat_id}`, c);
            });
          }else{
            if (json["message"] == undefined) {
              this.$set(this.reservations, `${json.date}-${json.seat_id}`, json);
            }else{
              alert(json["message"]);
            }
          }
        })
        .catch(error => {
          console.warn('Failed to parsing', error);
        })
    },
    deleteReservation: function(id) {
      fetch(`/api/reservations/${id}.json`, {
        method: 'DELETE',
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.token()
        },
        credentials: 'same-origin',
        redirect: 'manual'
      })
        .then(response => {
          for (var reservation in this.reservations) {
            if (this.reservations[reservation].id == id) {
              this.$delete(this.reservations, reservation);
            }
          }
        })
        .catch(error => {
          console.warn('Failed to parsing', error)
        })
    },
    is_holiday (isholiday) {
      return {
        "is-holiday": isholiday == 1
      }
    },
    reservation_hash_id (date, seatId) {
      return `reservation-${date}-${seatId}`;
    },
    memoBody (one_day) {
      return this.memos[one_day['ymd']].body;
    },
    memoId (one_day) {
      return `memo-${one_day}`;
    },
    createReservationForOneMonth (seatId) {
      let multipleDays = []
      if(this.admin_login == 1) {
        this.this_months.forEach(one_day => {
          multipleDays.push(one_day['ymd'])
        })
        this.createReservation(multipleDays, seatId)
      }
    },
    createReservationForOneDay (oneDay) {
      let seatIds = []
      if(this.admin_login == 1) {
        this.seats.forEach(seat => {
          seatIds.push(seat.id)
        })
        this.createReservation(oneDay, seatIds)
      }
    }
  }
}
</script>
