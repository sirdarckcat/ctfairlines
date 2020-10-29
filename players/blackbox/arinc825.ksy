meta:
  id: pcm825
  file-extension: pcm825
  endian: be
seq:
  - id: pcm825
    type: pcm825
types:
  pcm825:
    seq:
      - id: packet_type
        type: u2
      - id: packet_content
        type:
          switch-on: packet_type
          cases:
            1: v1_packet_content
  v1_packet_content:
    seq:
      - id: frame_counter
        type: u4
      - id: operation_code
        type: u2
      - id: packet_body
        type:
          switch-on: operation_code
          cases:
            0: can_noop
            1: can_write
            2: can_read
            3: can_ctrl
            4: can_write_rsp
            5: can_read_rsp
            6: can_ctrl_rsp
            7: can_status
  can_noop:
    seq:
      - id: service_code
        type: u2
  can_write:
    seq:
      - id: message_count
        type: u2
      - id: messages
        type: can_message
        repeat: expr
        repeat-expr: message_count
  can_read:
    seq:
      - id: message_count
        type: u2
      - id: messages
        type: can_message
        repeat: expr
        repeat-expr: message_count
  can_ctrl:
    seq:
      - id: service_code
        type: u2
      - id: control_message
        type:
          switch-on: service_code
          cases:
            10: init_can_chip_req
            12: reset_timestamp_req
            13: control_cpm_req
            100: config_ip_interface_req
            102: set_module_name_req
  can_write_rsp:
    seq:
      - id: service_code
        type: s2
  can_read_rsp:
    seq:
      - id: service_code
        type: s2
  can_ctrl_rsp:
    seq:
      - id: service_code
        type: s2
      - id: control_message
        type:
          switch-on: service_code
          cases:
            11: get_can_status_rsp
            14: get_temperatures_rsp
            101: get_module_info_rsp
  can_status:
    seq:
      - id: service_code
        type: u2
      - id: status
        type: get_can_status_rsp
  can_message:
    seq:
      - id: node_id
        type: u1
      - id: data_type
        type: u1
      - id: service_code
        type: u1
      - id: message_code
        type: u1
      - id: data
        type: u1
        repeat: expr
        repeat-expr: 4
      - id: byte_count
        type: u1
      - id: frame_type
        type: u1
      - id: message_control
        type: u2
      - id: can_identifier
        type: u4
      - id: can_status
        type: u2
      - id: error_counter
        type: u2
      - id: time_stamp
        type: u8
  bit_timing_register:
    seq:
      - id: res
        type: b1
      - id: tseg2
        type: b3
      - id: tseg1
        type: b4
      - id: sjw
        type: b2
      - id: brp
        type: b6
  status_register:
    seq:
      - id: res
        type: b8
      - id: boff
        type: b1
      - id: ewarn
        type: b1
      - id: epass
        type: b1
      - id: rxok
        type: b1
      - id: txok
        type: b1
      - id: lec
        type: b3
  error_counter:
    seq:
      - id: rp
        type: b1
      - id: rec60
        type: b7
      - id: tec70
        type: b8
  cpm_mode_status:
    seq:
      - id: status
        type: b4
      - id: unused
        type: b8
      - id: mode
        type: b4
  init_can_chip_req:
    seq:
      - id: bit_timing_register
        type: u2
      - id: silent_mode
        type: u2
      - id: loopback_mode
        type: u2
      - id: bussoff_mode
        type: u2
      - id: cpm_mode_status
        type: cpm_mode_status
  get_can_status_rsp:
    seq:
      - id: status_register
        type: status_register
      - id: error_counter
        type: error_counter
      - id: bit_timing_register
        type: bit_timing_register
      - id: can_mode
        type: u2
      - id: tx_bits
        type: u4
      - id: rx_bits
        type: u4
      - id: tx_messages
        type: u4
      - id: rx_messages
        type: u4
      - id: board_temperature
        type: u2
      - id: fpga_temperature
        type: u2
      - id: ip_address
        type: u4
      - id: module_name
        size: 32
      - id: cpm_buffer
        type: u2
  reset_timestamp_req:
    seq:
      - id: can_timer
        type: u2
  control_cpm_req:
    seq:
      - id: cpm_mode
        type: u2
  get_temperatures_rsp:
    seq:
      - id: board_temperature
        type: u2
      - id: fpga_temperature
        type: u2
  config_ip_interface_req:
    seq:
      - id: config
        size: 512
  get_module_info_rsp:
    seq:
      - id: firmware_loop_count
        type: u4
      - id: module_type
        type: u4
      - id: fpga_revision
        type: u4
      - id: hardware_revision
        type: u4
      - id: build_data_string
        type: u4
      - id: built_in_test_result
        type: u4
      - id: module_name
        size: 32
  set_module_name_req:
    seq:
      - id: module_name
        size: 32
