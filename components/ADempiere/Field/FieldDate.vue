<!--
 ADempiere-Vue (Frontend) for ADempiere ERP & CRM Smart Business Solution
 Copyright (C) 2017-Present E.R.P. Consultores y Asociados, C.A.
 Contributor(s): Yamel Senih ysenih@erpya.com www.erpya.com
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https:www.gnu.org/licenses/>.
-->

<template>
  <el-date-picker
    :ref="metadata.columnName"
    v-model="value"
    :format="formatView"
    :value-format="formatSend"
    :type="typePicker"
    range-separator="-"
    :placeholder="metadata.placeholder"
    :start-placeholder="$t('components.dateStartPlaceholder')"
    :end-placeholder="$t('components.dateEndPlaceholder')"
    unlink-panels
    :class="cssClassStyle"
    :readonly="Boolean(metadata.readonly)"
    :disabled="isDisabled"
    :picker-options="pickerOptions"
    @change="preHandleChange"
    @blur="focusLost"
    @focus="focusGained"
    @keydown.native="keyPressed"
    @keyup.native="keyReleased"
  />
</template>

<script>
// components and mixins
import FieldMixin from '@theme/components/ADempiere/Field/mixin/mixinField.js'

// constants
import { DATE_PLUS_TIME } from '@/utils/ADempiere/references'
import { OPERATORS_MULTIPLE_VALUES } from '@/utils/ADempiere/dataUtils'

/**
 * TODO: Improves set values into store and set in vales in component
 */
export default {
  name: 'FieldDate',

  mixins: [
    FieldMixin
  ],

  data() {
    return {
      pickerOptionsDate: {
        shortcuts: [{
          text: this.$t('components.date.Today'),
          onClick(picker) {
            picker.$emit('pick', new Date())
          }
        }, {
          text: this.$t('components.date.Yesterday'),
          onClick(picker) {
            const date = new Date()
            date.setTime(date.getTime() - 3600 * 1000 * 24)
            picker.$emit('pick', date)
          }
        }, {
          text: this.$t('components.date.Week'),
          onClick(picker) {
            const date = new Date()
            const monthEndDay = new Date(date.getFullYear(), date.getMonth() + 1, 0)
            picker.$emit('pick', monthEndDay)
          }
        }]
      },
      pickerOptionsDateRange: {
        shortcuts: [{
          text: this.$t('components.date.Yesterday'),
          onClick(picker) {
            const start = new Date()
            start.setTime(start.getTime() - 3600 * 1000 * 24)
            picker.$emit('pick', [start, start])
          }
        }, {
          text: this.$t('components.date.Week'),
          onClick(picker) {
            const start_date = new Date()
            start_date.setHours(0, 0, 0, 0)
            const end_date = new Date()
            const date = null
            const currenDate = date ? new Date(date) : new Date()
            const first = currenDate.getDate() - currenDate.getDay('monday')
            const last = first - 7
            start_date.setDate(last)
            end_date.setDate(first - 1)
            picker.$emit('pick', [start_date, end_date])
          }
        }, {
          text: this.$t('components.date.LastMonth'),
          onClick(picker) {
            const date = new Date()
            const monthEndDay = new Date(date.getFullYear(), date.getMonth(), 0)
            const monthStartDay = new Date(date.getFullYear(), date.getMonth() - 1, 1)
            picker.$emit('pick', [monthStartDay, monthEndDay])
          }
        }, {
          text: this.$t('components.date.CurrentMonth'),
          onClick(picker) {
            const date = new Date()
            const monthEndDay = new Date(date.getFullYear(), date.getMonth() + 1, 0)
            const monthStartDay = new Date(date.getFullYear(), date.getMonth(), 1)
            picker.$emit('pick', [monthStartDay, monthEndDay])
          }
        }]
      }
    }
  },

  computed: {
    typePicker() {
      let picker = 'date'
      if (this.isMultipleValues) {
        picker += 's'
        return picker
      }
      // Date + Time reference (16)
      if (this.metadata.displayType === DATE_PLUS_TIME.id) {
        picker += 'time'
      }
      if (this.metadata.isRange && !this.metadata.inTable) {
        picker += 'range'
      }
      return picker
    },
    cssClassStyle() {
      let styleClass = ' custom-field-date '
      if (!this.isEmptyValue(this.metadata.cssClassName)) {
        styleClass += this.metadata.cssClassName
      }

      if (this.isEmptyRequired) {
        styleClass += ' field-empty-required '
      }

      return styleClass
    },
    isMultipleValues() {
      return this.metadata.isAdvancedQuery &&
        OPERATORS_MULTIPLE_VALUES.includes(this.metadata.operator)
    },
    /**
     * Parse the date format to be compatible with element-ui
     */
    formatView() {
      let format = ''
      if (!this.isEmptyValue(this.metadata.vFormat)) {
        format = this.metadata.vFormat
          .replace(/[Y]/gi, 'y')
          .replace(/[m]/gi, 'M')
          .replace(/[D]/gi, 'd')
      }
      if (this.isEmptyValue(format)) {
        format = 'yyyy-MM-dd'
      }
      if (this.typePicker.replace('range', '') === 'datetime') {
        format = format + ' hh:mm:ss A'
      }
      return format
    },
    formatSend() {
      if (this.formatView) {
        return this.formatView
          .replace(/[h]/gi, 'H')
          .replace(/[aA]/gi, '')
      }
      return undefined
    },
    pickerOptions() {
      if (this.typePicker === 'daterange') {
        return this.pickerOptionsDateRange
      }
      return this.pickerOptionsDate
    },
    value: {
      get() {
        const { columnName, containerUuid, inTable } = this.metadata

        // table records values
        if (inTable) {
          // implement container manager row
          if (this.containerManager && this.containerManager.getCell) {
            return this.containerManager.getCell({
              containerUuid,
              rowIndex: this.metadata.rowIndex,
              columnName
            })
          }
        }

        // main panel values
        let value = this.$store.getters.getValueOfFieldOnContainer({
          parentUuid: this.metadata.parentUuid,
          containerUuid,
          columnName
        })
        if (!this.metadata.isRange) {
          return this.parseValue(value)
        }

        const valueTo = this.$store.getters.getValueOfFieldOnContainer({
          parentUuid: this.metadata.parentUuid,
          containerUuid,
          columnName: this.metadata.columnNameTo
        })

        value = this.parseValue([value, valueTo])
        return value
      },
      set(value) {
        const { columnName, containerUuid, inTable } = this.metadata

        // table records values
        if (inTable) {
          // implement container manager row
          if (this.containerManager && this.containerManager.setCell) {
            if (typeof value !== 'object' && value !== undefined) {
              value = new Date(value)
            }
            return this.containerManager.setCell({
              containerUuid,
              rowIndex: this.metadata.rowIndex,
              columnName,
              value
            })
          }
        }

        let startValue, endValue
        startValue = value

        if (this.metadata.isRange && !this.metadata.inTable && Array.isArray(value)) {
          startValue = value[0]
          endValue = value[1]
        }

        if (startValue === null) {
          startValue = undefined
          endValue = undefined
        }

        if (typeof startValue !== 'object' && startValue !== undefined) {
          startValue = new Date(startValue)
          endValue = new Date(endValue)
        }
        this.$store.commit('updateValueOfField', {
          parentUuid: this.metadata.parentUuid,
          containerUuid,
          columnName,
          value: startValue
        })

        if (!this.metadata.isRange) {
          return
        }
        this.$store.commit('updateValueOfField', {
          parentUuid: this.metadata.parentUuid,
          containerUuid,
          columnName: this.metadata.columnNameTo,
          value: endValue
        })
      }
    }
  },

  methods: {
    parseValue(value) {
      // not return undefined to v-model
      if (this.isEmptyValue(value)) {
        if (this.isMultipleValues) {
          return []
        }
        return null
      }

      if (this.isMultipleValues) {
        if (Array.isArray(value)) {
          value = value.map(itemValue => {
            if (typeof itemValue === 'object') {
              return itemValue.toUTCString()
            }
            return itemValue
          })
        } else {
          const tempValue = []
          if (!this.isEmptyValue(value)) {
            tempValue.push(value)
          }
          value = tempValue
        }
        return value
      }

      // instance date from long value
      if (typeof value === 'number') {
        value = new Date(value).toUTCString()
      }

      // generate range value
      if (this.metadata.isRange && !this.metadata.inTable) {
        let valueTo
        if (Array.isArray(value)) {
          valueTo = value[1]
          value = value[0]
        }
        if (typeof valueTo === 'number') {
          valueTo = new Date(valueTo).toUTCString()
        }
        if (this.isEmptyValue(valueTo)) {
          valueTo = undefined
        }
        value = [value, valueTo]
        if (this.isEmptyValue(value[0]) || this.isEmptyValue(value[1])) {
          value = []
        }
      }

      return value
    },
    // validate values before send values to store or server
    preHandleChange(value) {
      let startValue, endValue
      startValue = value

      if (this.typePicker === 'dates') {
        if (Array.isArray(value)) {
          value = value.map(itemValue => new Date(itemValue))
        }
        this.handleFieldChange({ value })
        return
      }

      if (this.metadata.isRange && !this.metadata.inTable && Array.isArray(value)) {
        startValue = value[0]
        endValue = value[1]
      }

      if (startValue === null) {
        startValue = undefined
        endValue = undefined
      }

      if (typeof startValue !== 'object' && startValue !== undefined) {
        startValue = new Date(startValue)
        endValue = new Date(endValue)
      }

      this.handleFieldChange({
        value: startValue,
        valueTo: endValue
      })
    }
  }
}
</script>

<style lang="scss">
  .custom-field-date {
    width: 100% !important;
  }
</style>
