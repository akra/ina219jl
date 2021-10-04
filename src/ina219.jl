module ina219

  using BaremetalPi
  include("./constants.jl")

  function init(device::String)
    return init(device, INA219_DEFAULT_ADDRESS)
  end

  function init(device::String, address::UInt8)
    init_i2c(device)
    return init(1, address)
  end

  function init(devId::Int, address::UInt8)
    return init(INA219(devId, address, INA219_MEASURE_MODE_SHUNT_CONTINUOUS, INA219_SAMPLE_MODE_128, INA219_BIT_MODE_12, INA219_POWER_GAIN_40, INA219_BUS_RANGE_32, 0, 1.0)) 
  end

  function init(device::INA219)
    i2c_slave(device.devId, device.address)
    reset(device)
    writeConfig(device)
    return device
  end

  function writeWord(device::INA219, address::UInt8, value::UInt16)
    data = (value & 0xff) << 8 | ((value >> 8) & 0xff)
    i2c_smbus_write_word_data(device.devId, address, data)
  end

  function readWord(device::INA219, address::UInt8)
    data = i2c_smbus_read_word_data(device.devId, address)
    return (data & 0xff) << 8 | ((data >> 8) & 0xff)
  end
 
  function reset(device::INA219)
    writeWord(device, INA219_CONF_REG, INA219_RESET)
  end

  function writeConfig(device::INA219)
    config::UInt16 = UInt16(device.mode) | UInt16(device.shuntMode) << 3 | UInt16(device.busMode) << 7 | UInt16(device.gain) << 11 | UInt16(device.range) << 13
    writeWord(device, INA219_CONF_REG, config)
    calibration = 4096
    device.currentFactor = Float16(10.0)
    if device.gain == INA219_POWER_GAIN_40
      calibration = 20480
      device.currentFactor = Float16(50.0)
    elseif device.gain == INA219_POWER_GAIN_80
      calibration = 10240
      device.currentFactor = Float16(25.0)
    elseif device.gain == INA219_POWER_GAIN_160
      calibration = 8192
      device.currentFactor = Float16(20.0)
    end
    writeWord(device, INA219_CALIBRATION_REG, UInt16(calibration))
  end

  function readShuntVoltage(device::INA219)
    return readWord(device, INA219_SHUNT_REG) * 0.01
  end

  function readBusVoltage(device::INA219)
    return readWord(device, INA219_BUS_REG) * 0.004
  end

  function readCurrent(device::INA219)
    return readWord(device, INA219_CURRENT_REG) / device.currentFactor
  end

  function close(device::INA219)
    i2c_close(device.devId)
  end

end
