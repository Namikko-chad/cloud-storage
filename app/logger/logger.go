package logger

import (
	"fmt"
	goLogger "log"
	"time"
)

type Logger struct {
	goLogger.Logger
	prefix string
}

func New(prefix string) *Logger {
	return &Logger{
		prefix: prefix,
	}
}

func (l *Logger) prepare(v []interface{}) []interface{} {
	args := make([]interface{}, len(v)+2)
	args[0] = l.prefix
	args[1] = time.Now().Format("2006-01-02 15:04:05")
	copy(args[2:], v)
	return args
}

func (l *Logger) Print(v ...interface{}) {
	fmt.Printf("[%s] %s %v\n", l.prepare(v)...)
}

func (l *Logger) Println(v ...interface{}) {
	fmt.Println(l.prefix, "", v)
}

func (l *Logger) Printf(format string, v ...interface{}) {
	fmt.Printf("[%s] %s "+format+"\n", l.prepare(v)...)
}

func (l *Logger) Info(v ...interface{}) {
	fmt.Print(l.prefix, "", v)
}

func (l *Logger) Warn(v ...interface{}) {
	fmt.Print(l.prefix, "", v)
}

func (l *Logger) Error(v ...interface{}) {
	fmt.Print(l.prefix, "", v)
}
