module C99
  # Most of the definition for this lives in core_support
  class NVM
    attr_accessor :attribute_x

    def override_method
      :overridden
    end

    def added_method
      :added
    end

    def add_multi_split_reg
      reg :multi_group, 0x0070, size: 16 do |reg|
        reg.bits 15,   :mike,  reset: 1
        reg.bits 14,   :bill,  reset: 0
        reg.bits 13,   :robert,  reset: 1
        reg.bits 12,   :james,  reset: 0
        reg.bits 11,   :james, reset: 1
        reg.bits 10,   :james, reset: 0
        reg.bits 9,    :paul,  reset: 1
        reg.bits 8,    :peter,  reset: 0
        reg.bits 7,    :mike,  reset: 1
        reg.bits 6,    :mike,  reset: 0
        reg.bits 5,    :paul,  reset: 1
        reg.bits 4,    :paul,  reset: 0
        reg.bits 3,    :mike, reset: 1
        reg.bits 2,    :robert, reset: 0
        reg.bits 1,    :bill,  reset: 0
        reg.bits 0,    :ian,  reset: 1
      end
    end

    def add_proth_reg
      reg :proth, 0x0024, size: 32 do |reg|
        reg.bits 31..24,   :fprot7,  reset: 0xFF
        reg.bits 23..16,   :fprot6,  reset: 0xEE
        reg.bits 15..8,    :fprot5,  reset: 0xDD
        reg.bits 7..0,     :fprot4,  reset: 0x11
      end
    end

    def add_non_byte_aligned_regs
      add_reg :non_aligned_small, 0x1000, size: 4
      add_reg :non_aligned_big, 0x1010, size: 10
      add_reg :non_aligned_small_msb0, 0x2000, size: 4, bit_order: :msb0
      add_reg :non_aligned_big_msb0, 0x2010, size: 10, bit_order: :msb0
    end

    def add_msb0_regs
      reg :SIUL2_MIDR1, 0x4, bit_order: :msb0  do |reg|
        bit 0..15,  :PARTNUM, res: 0b0101011101110111
        bit 16,     :ED
        bit 17..21, :PKG
        bit 24..27, :MAJOR_MASK
        bit 28..31, :MINOR_MASK
      end
    end
  end

  class NVMSub < NVM
    def redefine_data_reg
      add_reg :data,      0x40,   16,  d: { pos: 0, bits: 16 }
    end

    # Tests that the block format for defining registers works
    def add_reg_with_block_format
      # ** Data Register 3 **
      # This is dreg
      add_reg :dreg, 0x1000, size: 16 do |reg|
        # This is dreg bit 15
        reg.bit 15,    :bit15, reset: 1
        # **Bit 14** - This does something cool
        #
        # 0 | Coolness is disabled
        # 1 | Coolness is enabled
        reg.bits 14,    :bit14
        # This is dreg bit upper
        reg.bits 13..8, :upper
        # This is dreg bit lower
        # This is dreg bit lower line 2
        reg.bit 7..0,  :lower, writable: false, reset: 0x55
      end

      # This is dreg2
      reg :dreg2, 0x1000, size: 16 do
        # This is dreg2 bit 15
        bit 15,    :bit15, reset: 1
        # This is dreg2 bit upper
        bits 14..8, :upper
        # This is dreg2 bit lower
        # This is dreg2 bit lower line 2
        bit 7..0,  :lower, writable: false, reset: 0x55
      end

      # Finally a test that descriptions can be supplied via the API
      reg :dreg3, 0x1000, size: 16, description: "** Data Register 3 **\nThis is dreg3" do
        bit 15,    :bit15, reset: 1, description: 'This is dreg3 bit 15'
        bit 14, :bit14, description: "**Bit 14** - This does something cool\n\n0 | Coolness is disabled\n1 | Coolness is enabled"
        bits 13..8, :upper, description: 'This is dreg3 bit upper'
        bit 7..0,  :lower, writable: false, reset: 0x55, description: "This is dreg3 bit lower\nThis is dreg3 bit lower line 2"
      end

      reg :dreg4, 0x1000, size: 8, description: "** Data Register 4 **\nThis is dreg4" do
        bit 7..0, :busy, reset: 0x55, description: "**Busy Bits** - These do something super cool\n\n0 | Job0\n1 | Job1\n10 | Job2\n11 | Job3\n100 | Job4\n101 | Job5\n110 | Job6\n111 | Job7\n1000 | Job8\n1001 | Job9\n1010 | Job10\n1011 | Job11\n1100 | Job12\n1101 | Job13\n1110 | Job14\n1111 | Job15\n10000 | Job16\n10001 | Job17\n10010 | Job18"
      end
    end
  end
end
