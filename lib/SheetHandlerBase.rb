#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# = SheetHandlerBase.rb -- The TaskJuggler III Project Management Software
#
# Copyright (c) 2006, 2007, 2008, 2009, 2010 by Chris Schlaeger <cs@kde.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#

class TaskJuggler

  class SheetHandlerBase

    attr_accessor :workingDir, :noEmails

    def initialize(appName)
      @appName = appName
      # User specific settings
      @smtpServer= nil
      @senderEmail = nil
      @workingDir = nil

      # Controls the amount of output that is sent to the terminal.
      # 0: No output
      # 1: only errors
      # 2: errors and warnings
      # 3: All messages
      @outputLevel = 0
      # Controls the amount of information that is added to the log file. The
      # levels are identical to @outputLevel.
      @logLevel = 3
      # Set to true to not send any emails. Instead the email (header + body) is
      # printed to the terminal.
      @noEmails = false

      @logFile = 'timesheets.log'
    end

    def setWorkingDir
      # Make sure the user has provided a properly setup config file.
      error('\'smtpServer\' not configured') unless @smtpServer
      error('\'senderEmail\' not configured') unless @senderEmail

      # Change into the specified working directory
      begin
        Dir.chdir(@workingDir) if @workingDir
      rescue
        error("Working directory #{@workingDir} not found")
      end
    end

    def info(message)
      puts message if @outputLevel >= 3
      log('INFO', message) if @logLevel >= 3
    end

    def warning(message)
      puts message if @outputLevel >= 2
      log('WARN', message) if @logLevel >= 2
    end

    def error(message)
      $stderr.puts message if @outputLevel >= 1
      log("ERROR", message) if @logLevel >= 1
      exit 1
    end

    def log(type, message)
      timeStamp = Time.new.strftime("%Y-%m-%d %H:%M:%S")
      File.open(@logFile, 'a') do |f|
        f.write("#{timeStamp} #{type} #{@appName}: #{message}\n")
      end
    end

    def sendEmail(to, subject, message, attachment = nil)
      log('INFO', "Sent email '#{subject}' to #{to}")
      Mail.defaults do
        delivery_method :smtp, {
          :address => @smtpServer,
          :port => 25
        }
      end

      mail = Mail.new do
        subject subject
        body message
      end
      mail.to = to
      mail.from = @senderEmail
      mail.add_file attachment if attachment

      if @noEmails
        # For testing and debugging, we only print out the email.
        puts mail.to_s
      else
        # Actually send out the email via SMTP.
        mail.deliver
      end
    end

  end

end
