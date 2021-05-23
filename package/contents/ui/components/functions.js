/**
 * Convert memory bytes in human readable value
 * @param {number} memBytes the memory bytes
 * @returns the human readable memory
 */
function getHumanReadableMemory(memBytes) {
  var megaBytes = memBytes / 1024
  if (megaBytes <= 1024) {
    return Math.round(megaBytes) + 'M'
  }
  return Math.round((megaBytes / 1024) * 100) / 100 + 'G'
}

/**
 * Convert clock mhz in human readable value
 * @param {number} clockMhz the cpu clock
 * @returns the human readable cpu clock
 */
function getHumanReadableClock(clockMhz) {
  var clockNumber = clockMhz
  if (clockNumber < 1000) {
    return clockNumber + 'MHz'
  }
  clockNumber = clockNumber / 1000
  var floatingPointCount = 100
  if (clockNumber >= 10) {
    floatingPointCount = 10
  }
  return Math.round(clockNumber * floatingPointCount) / floatingPointCount + 'GHz'
}

/**
 * Add data in graph
 */
function addGraphData(model, graphItemPercent, graphGranularity) {
  // initial fill up
  while (model.count < graphGranularity) {
    model.append({
      graphItemPercent: 0,
    })
  }

  model.append({
    graphItemPercent: graphItemPercent,
  })
  model.remove(0)
}
