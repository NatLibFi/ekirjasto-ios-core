//
//  PrintHelper.swift
//

import Foundation

public enum LogLevel: Int {
  case info
  case debug
  case error
}

private func logLevelToString(_ level: LogLevel) -> String {
  switch level {
  case .info:
    return "INFO"
  case .debug:
    return "DEBUG"
  case .error:
    return "ERROR"
  }
}

public func printToConsole(
  file: String = #file,
  function: String = #function,
  lineNumber: Int = #line,
  _ logLevel: LogLevel,
  _ messageString: String,
  error: Error? = nil
) {

  let logLevelString = logLevelToString(logLevel)
  let fileName = URL(fileURLWithPath: file).lastPathComponent
  let functionName = function.split(separator: "(").first ?? ""
  let errorString = error == nil ? "" : "\n\(error!)"

  let printOutput =
    "[\(logLevelString)] \(fileName):\(lineNumber):\(functionName) - \(messageString) \(errorString)"

  print(printOutput)
}
